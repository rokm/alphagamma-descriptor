// dense_stereo_ground_truth
//
// An OpenGL-based renderer of ground-truth pixel maps for dense stereo
// models provided by Strecha et al. This program loads the PLY model
// file, renders each face with a different color, and stores the
// resulting image into a binary file.
//
// The resulting binary files can then be used to determine if two
// keypoints from two views are actually correspondences; i.e., if they
// both lie on the face with the same color.
//
// (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

#include <iostream>

#include <QtCore>
#include <QtWidgets>


void loadCameraFile (const QString &filename, QMatrix4x4 &pvm, int &imageWidth, int &imageHeight)
{
    // *** Load and parse the camera file ***
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly)) {
        throw QString("Failed to open camera file '%1'!").arg(filename);
    }

    // Process
    QTextStream stream(&file);

    // First nine parameters are the K matrix, in row-major order
    double K[3][3];
    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
            stream >> K[y][x];
        }
    }

    // Three zeros
    double zero;

    stream >> zero;
    stream >> zero;
    stream >> zero;

    // Transposed rotation matrix, in row-major order
    double R[3][3];

    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
            stream >> R[x][y]; // Switch coordinates to undo transpose
        }
    }

    // Translation vector
    double T[3];

    for (int i = 0; i < 3; i++) {
        stream >> T[i];
    }

    // Image width and height
    stream >> imageWidth;
    stream >> imageHeight;

    double near = 0.01;
    double far = 100.0;

    // *** Print camera parameters ***
    qDebug() << "Camera parameters:";

    qDebug() << " K:" << K[0][0] << K[0][1] << K[0][2];
    qDebug() << "   " << K[1][0] << K[1][1] << K[1][2];
    qDebug() << "   " << K[2][0] << K[2][1] << K[2][2];

    qDebug() << " R:" << R[0][0] << R[0][1] << R[0][2];
    qDebug() << "   " << R[1][0] << R[1][1] << R[1][2];
    qDebug() << "   " << R[2][0] << R[2][1] << R[2][2];

    qDebug() << " T:" << T[0] << T[1] << T[2];

    qDebug() << " image width:" << imageWidth;
    qDebug() << " image height:" << imageHeight;

    // *** OpenCV -> OpenGL projection matrix ***
    // In the transformations below, we accidentally swap the vertical
    // axis, which results in the image being rendered upside down.
    // However, this is good because it means we can directly read
    // the image contents in the pixel buffer and store it in the file
    // in same data order as the regular images.

    // NCD matrix
    QMatrix4x4 ncd;
    ncd.ortho(0, imageWidth, imageHeight, 0, near, far);

    // Perspective matrix
    QMatrix4x4 persp(
        K[0][0], K[0][1],     -K[0][2],       0.0,
            0.0, K[1][1],     -K[1][2],       0.0,
            0.0,     0.0, (near+far), near*far,
            0.0,     0.0,          -1.0,      0.0);

    // Full projection matrix
    QMatrix4x4 proj = ncd*persp;

    // Model/view matrix: [ R, -R*T ]
    QMatrix4x4 vm;
    vm.rotate(180.0f, 1.0, 0.0, 0.0); // OpenCV->OpenGL coordinate system
    vm = vm*QMatrix4x4(
        R[0][0], R[0][1], R[0][2], -(R[0][0]*T[0] + R[0][1]*T[1] + R[0][2]*T[2]),
        R[1][0], R[1][1], R[1][2], -(R[1][0]*T[0] + R[1][1]*T[1] + R[1][2]*T[2]),
        R[2][0], R[2][1], R[2][2], -(R[2][0]*T[0] + R[2][1]*T[1] + R[2][2]*T[2]),
            0.0,     0.0,     0.0,  1.0);

    // Compute PVM matrix for scene
    pvm = proj*vm;

    qDebug() << pvm;
}

//
void uploadModelFromPlyFile (const QString &filename, QOpenGLBuffer &vertexBuffer, QOpenGLBuffer &colorBuffer, int &numFaces)
{
    int numVertices;
    int progress;

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly)) {
        throw QString("Failed to open model file!");
    }

    // Process
    QTextStream stream(&file);
    QString line;

    qDebug() << "Parsing header...";

    // "ply"
    line = stream.readLine();
    if (line.compare("ply")) {
        throw QString("Model file is not a PLY file!");
    }

    // "format ascii 1.0"
    line = stream.readLine();
    if (line.compare("format ascii 1.0")) {
        throw QString("Unsupported model file!");
    }

    // "element vertex XXX"
    line = stream.readLine();
    if (!line.startsWith("element vertex")) {
        throw QString("Unsupported model file!");
    }
    numVertices = line.split(" ")[2].toInt();

    qDebug() << "Model has" << numVertices << "vertices";

    // "property float x"
    line = stream.readLine();
    if (!line.startsWith("property float x")) {
        throw QString("Unsupported model file!");
    }

    // "property float y"
    line = stream.readLine();
    if (!line.startsWith("property float y")) {
        throw QString("Unsupported model file!");
    }

    // "property float z"
    line = stream.readLine();
    if (!line.startsWith("property float z")) {
        throw QString("Unsupported model file!");
    }

    // "element face XXX"
    line = stream.readLine();
    if (!line.startsWith("element face")) {
        throw QString("Unsupported model file!");
    }
    numFaces = line.split(" ")[2].toInt();

    qDebug() << "Model has" << numFaces << "faces";

    // "property list uchar int vertex_indices"
    line = stream.readLine();
    if (!line.startsWith("property list uchar int vertex_indices")) {
        throw QString("Unsupported model file!");
    }

    // "end_header"
    line = stream.readLine();
    if (!line.startsWith("end_header")) {
        throw QString("Unsupported model file!");
    }

    // Vertices
    qDebug() << "Parsing vertices...";

    QVector<QVector3D> vertices;
    vertices.reserve(numVertices);

    progress = 0;
    for (int i = 0; i < numVertices; i++) {
        QStringList tokens;

        line = stream.readLine();
        tokens = line.split(" ");

        if (tokens.size() != 3) {
            throw QString("Invalid number of vertex tokens!");
        }

        vertices.append(QVector3D(tokens[0].toDouble(), tokens[1].toDouble(), tokens[2].toDouble()));

        // Display progress
        if (i*10 / numVertices > progress) {
            progress = i*10 / numVertices;
            qDebug().nospace() << " " << progress*10 << "%";
        }
    }

    // Faces; these are stored in form of index lists, so ideally, we
    // would read them into an index buffer. However, as we wish to
    // color-code each face individually, we need to specify colors on
    // per face basis, and need to duplicate the vertices

    // Allocate and map vertex buffer
    qDebug() << "Allocating and mapping vertex buffer";
    if (!vertexBuffer.bind()) {
        qFatal("Failed to bind vertex buffer!");
    }
    vertexBuffer.setUsagePattern(QOpenGLBuffer::StreamDraw);
    vertexBuffer.allocate(numFaces*3*3*sizeof(float)); // three vertices per face, each having three float coordinates

    float *vertexBufferPtr = static_cast<float *>(vertexBuffer.map(QOpenGLBuffer::WriteOnly));
    if (!vertexBufferPtr) {
        qFatal("Failed to map vertex buffer!");
    }

    // Allocate and map color buffer
    qDebug() << "Allocating and mapping color buffer";
    if (!colorBuffer.bind()) {
        qFatal("Failed to bind color buffer!");
    }

    colorBuffer.setUsagePattern(QOpenGLBuffer::StreamDraw);
    colorBuffer.allocate(numFaces*3*sizeof(unsigned int)); // three vertices per face, each having a RGBA color stored as unsigned int

    unsigned int *colorBufferPtr = static_cast<unsigned int *>(colorBuffer.map(QOpenGLBuffer::WriteOnly));
    if (!colorBufferPtr) {
        qFatal("Failed to map color buffer!");
    }

    // Parse faces and write vertex data
    qDebug() << "Parsing faces and writing vertex data...";

    progress = 0;
    for (int i = 0; i < numFaces; i++) {
        QStringList tokens;

        line = stream.readLine();
        tokens = line.split(" ");

        if (tokens.size() != 4) {
            throw QString("Invalid number of face tokens!");
        }

        if (tokens[0].toInt() != 3) {
            throw QString("Only three-vertex faces are supported!");
        }

        // Write data
        for (int v = 0; v < 3; v++) {
            // Vertices
            int vertexIdx = tokens[1 + v].toInt();

            if (vertexIdx >= vertices.size()) {
                throw QString("Invalid vertex index in face %1").arg(i);
            }

            const QVector3D &vertex = vertices[vertexIdx];

            *vertexBufferPtr++ = vertex.x();
            *vertexBufferPtr++ = vertex.y();
            *vertexBufferPtr++ = vertex.z();

            // Color; start with index 1, so that 0 has a reserved
            // meaning
            *colorBufferPtr++ = 1 + i;
        }

        // Display progress
        if (i*10 / numFaces > progress) {
            progress = i*10 / numFaces;
            qDebug().nospace() << " " << progress*10 << "%";
        }
    }

    // Unmap buffers
    qDebug() << "Unmapping buffers...";

    if (!vertexBuffer.bind()) {
        qFatal("Failed to bind vertex buffer!");
    }
    if (!vertexBuffer.unmap()) {
        qFatal("Failed to unmap vertex buffer!");
    }

    if (!colorBuffer.bind()) {
        qFatal("Failed to bind color buffer!");
    }
    if (!colorBuffer.unmap()) {
        qFatal("Failed to unmap color buffer!");
    }

    // Sanity check
    if (!stream.atEnd()) {
        qWarning() << "Parsing did not end at the end of stream!";
    }
}

void writePixelData (const QString &filename, const unsigned int *buffer, int imageWidth, int imageHeight)
{
    // *** Load and parse the camera file ***
    QFile file(filename);
    if (!file.open(QIODevice::WriteOnly)) {
        throw QString("Failed to open camera file '%1'!").arg(filename);
    }

    QDataStream stream(&file);
    stream.setVersion(QDataStream::Qt_5_4);
    stream.setFloatingPointPrecision(QDataStream::SinglePrecision);
    stream.setByteOrder(QDataStream::LittleEndian);

    quint8 sig[4] = { 'D', 'G', 'T', 'M' };

    stream << sig[0];
    stream << sig[1];
    stream << sig[2];
    stream << sig[3];

    stream << imageWidth;
    stream << imageHeight;

    // The image data is stored in left-right, bottom-up order. But, as
    // we rendered the image upside down, we can directly read the
    // pixel values and store them to our binary data stream.
    for (int y = 0; y < imageHeight; y++) {
        QDebug line = qDebug().noquote();
        for (int x = 0; x < imageWidth; x++) {
            stream << *buffer++;
        }
    }
}

void checkGLError (QOpenGLFunctions *glFunctions)
{
    GLenum err = glFunctions->glGetError();

    while (err != GL_NO_ERROR) {
        switch (err) {
            case GL_INVALID_OPERATION: {
                qWarning() << "GL_INVALID_OPERATION";
                break;
            }
            case GL_INVALID_ENUM: {
                qWarning() << "GL_INVALID_ENUM";
                break;
            }
            case GL_INVALID_VALUE: {
                qWarning() << "GL_INVALID_VALUE";
                break;
            }
            case GL_OUT_OF_MEMORY: {
                qWarning() << "GL_OUT_OF_MEMORY";
                break;
            }
            case GL_INVALID_FRAMEBUFFER_OPERATION: {
                qWarning() << "GL_INVALID_FRAMEBUFFER_OPERATION";
                break;
            }
        }

        err = glFunctions->glGetError();
    }
}


int main (int argc, char **argv)
{
    QApplication app(argc, argv);

    if (app.arguments().size() != 4) {
        std::cerr << "Usage: " << argv[0] << " <ply_filename> <camera_file> <output_file>" << std::endl;
        return -1;
    }

    QString plyFilename = app.arguments()[1];
    QString cameraFilename = app.arguments()[2];
    QString outputFilename = app.arguments()[3];

    // Enable debug channel
    QLoggingCategory::defaultCategory()->setEnabled(QtDebugMsg, true);

    // FIXME: load camera calibration
    int imageWidth;
    int imageHeight;
    QMatrix4x4 pvmMatrix;

    try {
        loadCameraFile(cameraFilename, pvmMatrix, imageWidth, imageHeight);
    } catch (const QString &errorMessage) {
        qFatal(qUtf8Printable(QString("Failed to load camera file: %1").arg(errorMessage)));
    }

    // Initialize OpenGL context on top of an off-screen surface
    qDebug() << "Initializing OpenGL context...";

    QOffscreenSurface surface;
    QOpenGLContext context;

    // Set OpenGL to 3.3 core profile
    QSurfaceFormat surfaceFormat;
    surfaceFormat.setVersion(3, 3);
    surfaceFormat.setProfile(QSurfaceFormat::CoreProfile);
    surface.setFormat(surfaceFormat);

    surface.create();

    if (!surface.isValid()) {
        qFatal("Failed to create offscreen surface!");
    }

    if (!context.create()) {
        qFatal("Failed to create OpenGL context!");
    }

    if (!context.makeCurrent(&surface)) {
        qFatal("Failed to create context current!");
    }

    // Functions pointer
    QOpenGLFunctions *glFunctions = context.functions();

    // Display OpenGL parameters
    surfaceFormat = context.format();
    qDebug() << "OpenGL";
    qDebug() << " major version: " << surfaceFormat.majorVersion();
    qDebug() << " minor version: " << surfaceFormat.minorVersion();

    // *** Create shader program ***
    qDebug() << "Creating shader program";

    QOpenGLShaderProgram shaderProgram;

    shaderProgram.addShaderFromSourceFile(QOpenGLShader::Vertex, ":/shaders/basic.vert");
    shaderProgram.addShaderFromSourceFile(QOpenGLShader::Fragment, ":/shaders/basic.frag");
    if (!shaderProgram.link()) {
        qFatal("Failed to link shader program!");
    }

    // *** Create buffers ***
    qDebug() << "Creating buffers...";

    QOpenGLBuffer vertexBuffer(QOpenGLBuffer::VertexBuffer);
    QOpenGLBuffer colorBuffer(QOpenGLBuffer::VertexBuffer);

    if (!vertexBuffer.create()) {
        qFatal("Failed to create vertex buffer!");
    }

    if (!colorBuffer.create()) {
        qFatal("Failed to create color buffer!");
    }

    // *** Parse data and upload it to buffers ***
    int numFaces;

    try {
        uploadModelFromPlyFile(plyFilename, vertexBuffer, colorBuffer, numFaces);
    } catch (const QString &errorMessage) {
        qFatal(qUtf8Printable(QString("Failed to (up)load model: %1").arg(errorMessage)));
    }

    // *** Set up data for rendering ***
    qDebug() << "Preparing for rendering...";

    // Create a VAO
    QOpenGLVertexArrayObject vao;

    if (!vao.create()) {
        qFatal("Failed to create a VAO!");
    }
    vao.bind();

    shaderProgram.bind();

    // Set vertex data
    if (!vertexBuffer.bind()) {
        qFatal("Failed to bind vertex buffer!");
    }
    shaderProgram.setAttributeBuffer("vertex", GL_FLOAT, 0, 3);
    shaderProgram.enableAttributeArray("vertex");

    // Set color data
    if (!colorBuffer.bind()) {
        qFatal("Failed to bind color buffer!");
    }
    shaderProgram.setAttributeBuffer("color", GL_UNSIGNED_BYTE, 0, 4);
    shaderProgram.enableAttributeArray("color");

    // Set PVM matrix
    shaderProgram.setUniformValue("pvm", pvmMatrix);

    // *** Create an FBO ***
    QOpenGLFramebufferObjectFormat fboFormat;
    fboFormat.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
    fboFormat.setSamples(0); // No multisampling

    QOpenGLFramebufferObject fbo(imageWidth, imageHeight, fboFormat);


    // *** Render ***
    checkGLError(glFunctions);

    fbo.bind();

    // Set viewport
    glFunctions->glViewport(0, 0, imageWidth, imageHeight);

    // Setup state
    glFunctions->glClearColor(0.0, 0.0, 0.0, 0.0); // 00000000h, equivalent to the lowest index value

    // Clear scene
    glFunctions->glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Render model
    qDebug() << "Checking for errors before draw arrays...";
    checkGLError(glFunctions);

    glFunctions->glDrawArrays(GL_TRIANGLES, 0, numFaces*3);

    qDebug() << "Checking for errors after draw arrays...";
    checkGLError(glFunctions);

    // Flush
    glFunctions->glFlush();

    qDebug() << "Checking for errors at end of rendering...";
    checkGLError(glFunctions);

    // *** Read pixel data ***
    qDebug() << "Reading pixel data...";

    QOpenGLBuffer pixelBuffer(QOpenGLBuffer::PixelPackBuffer);
    if (!pixelBuffer.create()) {
        qFatal("Failed to create pixel buffer!");
    }

    pixelBuffer.bind();
    pixelBuffer.setUsagePattern(QOpenGLBuffer::StreamRead);
    pixelBuffer.allocate(imageWidth*imageHeight*4); // w*h*rgba

    // NOTE: this will actually read the values in ARGB order
    glFunctions->glReadPixels(0, 0, imageWidth, imageHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0);

    const unsigned int *pixelBufferPtr = static_cast<const unsigned int *>(pixelBuffer.map(QOpenGLBuffer::ReadOnly));
    if (!pixelBufferPtr) {
        qFatal("Failed to map pixel buffer!");
    }

    try {
        writePixelData(outputFilename, pixelBufferPtr, imageWidth, imageHeight);
    } catch (const QString &errorMessage) {
        qFatal(qUtf8Printable(QString("Failed to write output file: %1").arg(errorMessage)));
    }

    // Exit
    return 0;
}
