function ImageRenderer({ question }) {
  const { media } = question;

  if (!media || !media.image_url) {
    return (
      <div className="text-center py-12">
        <p className="text-red-400">No image provided</p>
      </div>
    );
  }

  return (
    <div className="flex items-center justify-center w-full">
      <img
        src={media.image_url}
        alt="Question image"
        className="max-w-full max-h-[500px] rounded-lg shadow-2xl"
        onError={(e) => {
          e.target.style.display = 'none';
          e.target.nextSibling.style.display = 'block';
        }}
      />
      <div style={{ display: 'none' }} className="text-red-400 text-center py-12">
        Failed to load image
      </div>
    </div>
  );
}

export default ImageRenderer;
